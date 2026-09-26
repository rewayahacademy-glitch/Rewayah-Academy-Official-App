# Rewayah Academy - 03_ADMIN_VALIDATION_DOSSIERS

**Version :** V1.2 - gouvernance design et KYC  
**Date :** 26/09/2026  
**Statut :** PROPOSITION À VALIDER PAR LE DIRECTEUR  
**Périmètre :** revue des dossiers enseignants et familles, préalable opérationnel au rôle Enseignant  
**Rôle principal :** Administration  
**Domaine :** Personnes  
**Écran canonique existant :** `ADM-02`  
**Route existante :** `/admin/personnes/dossiers`

---

# 0. Pourquoi ce document vient avant le rôle Enseignant

L'ordre de travail canonique place cette verticale immédiatement après `02_CLASSE_ET_VISIO.md` et avant `04_ENSEIGNANT.md`.

Ce lot est volontairement étroit. Il ne redessine pas toute l'administration. Il doit rendre réellement utilisable le parcours qui permet à une personne autorisée de l'administration de revoir un dossier d'inscription, consulter la pièce déposée, effectuer les vérifications déjà prévues par le produit, puis prendre une décision serveur traçable.

Le dépôt décrit actuellement `ADM-02` comme un écran atteignable, mais le parcours est fragile. Il peut se bloquer si le genre de l'administrateur n'est pas renseigné. Le profil commun est en lecture seule, donc l'administrateur n'a actuellement aucun moyen visible de corriger ce prérequis.

La recette opérationnelle de cette verticale est un préalable au parcours réel d’un enseignant soumis à validation. La rédaction et les travaux indépendants de `04_ENSEIGNANT.md` peuvent avancer en parallèle.

Ce document ne doit pas être interprété comme une autorisation de réécrire l'authentification, le routeur, le stockage KYC, les rôles ou l'ensemble du domaine Administration.


**Directive de progression du 26/09/2026 :** cette révision formalise des règles transversales de design et une décision KYC, mais elle n'ordonne aucun retour arrière sur les étapes déjà terminées, vérifiées ou en cours de livraison. Les nouveaux standards sont publiés maintenant pour guider les nouvelles spécifications et les nouveaux visuels. Leur harmonisation rétroactive dans le code et dans les lots déjà livrés est différée jusqu'à ce que les visuels de tous les rôles soient implémentés, sauf demande explicite du directeur sur un écran ou un lot précis.

Exemple directeur : le lot **Tuteur - compléments** n'a pas atteint le niveau visuel attendu. Il ne doit pourtant pas être rouvert, réinitialisé ou recommencé maintenant pour cette seule raison. Les écarts sont consignés dans la future passe d'harmonisation UI. Le chantier continue d'abord vers les autres rôles et les visuels manquants.

---

# 1. Autorité et hiérarchie des décisions

Claude Code applique la hiérarchie canonique de `00_LIRE_D_ABORD.md` :

1. demande explicite la plus récente du directeur ;
2. décisions canoniques, notamment `DOSSIER_POUR_CHATGPT.md`, A §1 bis à §1 quater ;
3. contrats effectivement migrés et vérifiés, avec plan compatible en cas de divergence ;
4. présent document, pour les propositions du parcours ADM-02 ;
5. système de design gelé, composants partagés et référentiels UX applicables.

Le code prouve un état technique, pas la validité d'une décision métier. Une règle existante contestée est documentée, jamais supprimée silencieusement. Les protections d'accès restent effectives pendant toute correction.

**Portée de cette révision :** document uniquement. Aucun dépôt applicatif, environnement Supabase ou accès R2 n'a été audité ou modifié. L'inventaire source décrit le commit `cefab7f` du 24/09/2026, pas une preuve du code actuel. Le mandat frontend de la section F concerne le chantier Tuteur : ne pas le transformer en interdiction universelle, ni déduire de cette spécification une autorisation de migration ou de déploiement. Le coordinateur confirme le périmètre d'exécution applicable au lot Admin ; à défaut, spécifier les ports manquants sans modifier le backend distant.

Une maquette ne peut jamais élargir une permission.

Une proposition de ce document ne peut jamais remplacer silencieusement une règle serveur.

Une donnée absente du contrat serveur ne doit pas être inventée pour remplir une carte.

---

# 2. Faits source à préserver

Les faits ci-dessous sont rapportés par le dossier fourni, à recontrôler avant implémentation :

- l'application est Flutter, avec Supabase, LiveKit et stockage privé R2 ;
- l'administration possède une coquille propre avec domaines ;
- `ADM-02` existe sur `/admin/personnes/dossiers` ;
- `/admin/personnes` redirige actuellement vers cet écran ;
- le point d'entrée existe depuis le domaine Personnes et depuis le compteur `Dossiers à valider` du centre de commande ;
- le fonctionnement actuel traite un dossier à la fois ;
- le dossier présente une pièce d'identité déposée ;
- trois vérifications existent déjà dans le parcours actuel ;
- les actions existantes sont `Valider le dossier` et `Refuser`, avec motif pour le refus ;
- l'écran ne montre aujourd'hui que les pièces déposées ;
- l'écran se bloque si le genre de l'administrateur est absent ;
- le profil commun est actuellement en lecture seule ;
- le portail d'attente est partagé par les comptes tuteur et enseignant ;
- le portail d'attente peut afficher les états incomplet, en vérification, refusé avec motif et suspendu ;
- le dépôt de pièce propose Carte d'identité, Passeport, Titre de séjour ou Autre et contrôle un plafond de 8 Mo côté parcours existant ;
- la pièce d'identité est distincte de la photo publique d'un enseignant et distincte du portrait d'un élève ;
- l'enseignant actif et assignable doit posséder une photo publique professionnelle, mais cette photo publique ne devient pas une pièce KYC ;
- le système de notifications applicatives n'est pas actuellement garanti ;
- la revue administrative et les pièces de tiers sont réservées aux personnes explicitement habilitées ; les accès personnels de dépôt ou de correction restent distincts ;
- les actions sensibles doivent être auditées ;
- le web doit être une vraie version ordinateur ;
- les titres sont en DM Sans et le reste en Plus Jakarta Sans ;
- une carte groupée est un seul rectangle séparé par des filets internes ;
- une fonction doit vivre à un seul endroit.

---

## 2.1 Traçabilité des sources

| Sujet | Source documentaire précise |
|---|---|
| Existence, route, trois contrôles et blocage de genre | Dossier E §0, constat 9 ; E §6, ligne ADM-02 ; E §17, point 1 |
| Portail, dépôt et refus | Dossier D §2.1, SM-06 à SM-09 ; E §2 |
| Gardes et racines après activation | Dossier E §1.1 ; E §14, KYC enseignant |
| Profil partagé en lecture seule | Dossier E §1.4 |
| AdminShell et composants | Dossier C §3, §8, §9 ; E §6 |
| Familles incluses dans ce lot | PROMPT_CHATGPT_SPECS_VERTICALES, ordre de travail, point 3 |
| Sécurité et stockage | 02_ARCHITECTURE_ET_SECURITE, règles 1, 3, 5, 7 et 8 |
| Honnêteté des preuves | 00_LIRE_D_ABORD, Statuts de preuve ; dossier A §1 ter bis |

La file sélectionnable, les filtres, la pagination, les confirmations nouvelles et les contrats nommés au §17 sont des **PROPOSITIONS**, pas des capacités attestées. Conserver le traitement séquentiel existant s'il suffit ; ne pas bloquer sa réparation sur un nouveau service de liste. Toute fonction proposée sans backend disponible indique son indisponibilité.

---

# 3. Points non prouvés par les sources

Les sources fournies ne donnent pas les libellés exacts des trois vérifications actuelles de `ADM-02`.

**INTERDICTION :** ne pas inventer trois contrôles métier sous prétexte de compléter l'UI.

Avant modification, Claude doit retrouver dans le code et l'i18n :

- les trois libellés visibles actuels ;
- leur source de données ;
- leur caractère obligatoire ou informatif ;
- leur mode actuel de validation ;
- l'effet serveur de chaque contrôle.

S'ils n'existent plus dans le code courant, Claude arrête la modification de cette sous-partie, documente la divergence et demande un arbitrage. Il peut continuer les éléments indépendants.

La raison historique du prérequis `genre de l'administrateur` reste à retrouver dans le code et les règles serveur, mais la **décision du directeur du 26/09/2026** fixe désormais son statut produit :

1. la contrainte de genre peut rester disponible comme politique de confidentialité de la revue KYC ;
2. elle doit être **configurable côté serveur** ;
3. seul un **Super Admin disposant de la capability de configuration correspondante** peut l'activer ou la désactiver ;
4. lorsqu'elle est activée, Claude conserve le comportement serveur réellement existant après l'avoir identifié et testé, sans inventer la logique exacte de correspondance ;
5. lorsqu'elle est désactivée, **le genre ne doit plus filtrer la file, la lecture de pièce ni la décision** : tout reviewer KYC autorisé peut traiter les dossiers accessibles à son périmètre, homme ou femme ;
6. un reviewer ordinaire ne peut jamais modifier cette politique ni son propre genre pour étendre ses droits ;
7. chaque changement de politique est audité avec acteur, valeur précédente, nouvelle valeur et date serveur.

**DÉCISION D-ADM-KYC-GENRE-01 :** la contrainte n'est donc ni supprimée globalement ni rendue obligatoire globalement. Elle devient une **politique Super Admin activable/désactivable**, imposée par le serveur et reflétée par l'UI.

Claude doit encore vérifier avant code : le champ actuellement lu, le filtrage réellement appliqué, les RLS/RPC concernées, le comportement actuel quand le genre manque et le point de configuration Super Admin déjà existant ou à créer.

---

# 4. Validation obligatoire des propositions UX/UI avec les standards 2026

Cette section est une instruction d'exécution à Claude Code.

Avant d'implémenter les propositions de disposition marquées `PROPOSITION`, Claude doit les confronter aux standards officiels et reconnus disponibles au moment de l'exécution.

## 4.1 Référentiels minimum à vérifier

Claude vérifie au minimum :

- documentation Flutter officielle sur les interfaces adaptive et responsive ;
- recommandations Flutter sur souris, clavier, hover, focus, scroll et raccourcis ;
- Material Design 3 pour hiérarchie, composants, feedback, dialogues, densité et états ;
- Apple Human Interface Guidelines pour les adaptations iOS réellement pertinentes ;
- WCAG 2.2 niveau AA ;
- EN 301 549 si applicable : vérifier l’édition publiée et sa portée ; ne pas inventer une « version 2026 » ;
- heuristiques de Nielsen ;
- principes de Fitts, Hick, proximité Gestalt, visibilité d'état et prévention des erreurs ;
- Atlassian Design System et IBM Carbon uniquement comme références complémentaires de tokenisation, spacing et cohérence de composants lorsque la Bible Rewayah ne tranche pas déjà ;
- bonnes pratiques Baymard applicables aux formulaires, validation et prévention d'erreurs.

**Exclusion décidée par le directeur :** GOV.UK Design System n'est pas une référence de design pour Rewayah. Aucun agent ne doit justifier une composition, un CTA, une densité ou une hiérarchie visuelle Rewayah par GOV.UK.

## 4.2 Preuve attendue

Claude produit avant intégration un court `UX_REVIEW_03_ADMIN_DOSSIERS.md` dans le dossier de pilotage du lot, contenant :

- proposition contrôlée ;
- standard ou source officielle consultée ;
- date de consultation ;
- règle utile ;
- conclusion : conforme, ajustée ou non applicable ;
- modification effectuée si nécessaire ;
- justification de toute dérogation.

Claude ne doit pas écrire seulement « conforme aux standards UX ». Il doit donner la règle et la conséquence concrète.

## 4.3 Limite de cette validation

Les standards UX/UI peuvent améliorer :

- la disposition ;
- la densité ;
- la lisibilité ;
- le focus clavier ;
- le positionnement des actions ;
- la confirmation d'une décision ;
- les messages d'erreur ;
- l'adaptation mobile, tablette et ordinateur.

Ils ne peuvent pas modifier :

- les permissions ;
- les règles KYC ;
- les états serveur ;
- les critères de validation métier ;
- la rétention des pièces ;
- la visibilité des données sensibles ;
- le nombre ou la nature des vérifications métier ;
- l'effet juridique d'une décision.

Si un standard UX suggère un comportement qui contredit une règle métier prouvée, la règle métier prévaut.



# 4 bis. Contrat transversal de design gelé - DESIGN-GOV-2026-09-26

Cette section formalise la décision du directeur issue de la revue des écrans web et des lots récents. Elle doit être propagée par l'agent orchestrateur dans les sources actives partagées. Elle reste gelée jusqu'à une nouvelle décision explicite et datée du directeur.

Elle ne remplace pas les composants déjà prouvés dans le dépôt. Lorsqu'une métrique existe déjà dans le thème ou un composant partagé, **la valeur existante prouvée prime**. Les règles ci-dessous donnent surtout le rôle sémantique des métriques pour empêcher chaque agent de choisir arbitrairement un nombre.

## 4 bis.1 Contrat A - Spacing & Layout

Échelle autorisée existante : `4, 8, 12, 16, 20, 24, 32, 40, 48, 64` logical pixels. Aucun widget métier ne choisit librement une valeur hors de cette échelle.

| Relation | Valeur Rewayah | Règle |
|---|---:|---|
| texte et aide/erreur immédiatement liée | 4 | relation micro, même composant |
| icône et libellé | 8 | sauf anatomie de composant existante plus précise |
| titre et sous-titre | 8 | même unité sémantique |
| titre de section et groupe/carte qu'il introduit | 8 | le groupe reste perceptuellement lié |
| champs successifs d'un même formulaire | 12 | valeur par défaut de formulaire |
| ligne groupée : icône vers libellé | 12 | conserver `GroupeReglages` existant |
| **objet, carte ou bloc vers le CTA qui agit directement dessus** | **16** | règle transversale obligatoire |
| checkbox/consentement vers CTA qu'elle conditionne | 16 | même décision |
| deux boutons du même action group | 8 | secondaire puis primaire en LTR |
| deux cartes autonomes d'une même section | 16 | même niveau hiérarchique |
| header/actions internes d'`AppCard` | 16 | conserver l'anatomie existante |
| groupe de champs vers groupe suivant | 20 | séparation fonctionnelle |
| section vers section suivante, mobile | 24 | séparation structurelle |
| section vers section suivante, tablette/desktop | 32 | respiration structurelle |
| padding de page mobile | 16 | `PageShell`/layout partagé |
| padding de page tablette | 24 | layout partagé |
| padding de page desktop | 32 | layout partagé |
| padding interne `AppCard` | 20 sous 600, 24 à partir de 600 | conserver le composant existant |
| padding de ligne groupée | 16 horizontal, 12 vertical | conserver `GroupeReglages` |

**Interdiction :** un CTA lié à un contenu ne peut pas être déplacé arbitrairement en bas du viewport si son objet est très au-dessus. Un écart de 40, 48 ou 64 entre l'objet et son CTA signifie visuellement une séparation de groupe et est donc interdit sauf structure explicitement documentée.

Les écrans utilisent des tokens sémantiques, par exemple `space.relatedAction`, `space.actionGroup`, `space.section`, et non des `SizedBox` choisis au jugé. Le coordinateur mappe ces rôles aux tokens réels du dépôt au lieu de créer des constantes concurrentes.

## 4 bis.2 Contrat B - CTA & Actions

`ActionPrincipale` reste le point d'entrée canonique des boutons. Son anatomie existante ne doit pas être redessinée localement : hauteur 52, padding interne 20 horizontal x 12 vertical, rayon 12, `labelLarge`, quatre niveaux d'emphase. La cible interactive reste au moins 48 dp.

Règles de hiérarchie :

1. un seul CTA **principal visuellement dominant** par écran ou contexte de décision ;
2. deux actions secondaires au plus dans le même action group ;
3. une action destructive utilise le niveau destructif existant, jamais un second bouton plein concurrent ;
4. une collection de cartes répétées ne porte pas un gros CTA plein identique sur chaque carte si la carte elle-même ou un lien tertiaire peut ouvrir l'action ;
5. les actions secondaires, contextuelles et rares utilisent secondaire, tertiaire, menu ou interaction de ligne selon leur nature ;
6. un CTA dit exactement l'action qu'il exécute.

Règles de placement :

- une action qui poursuit ou confirme un flux est placée au **trailing edge** de son action group ;
- retour, précédent et annulation sont au **leading edge** ou avant l'action principale dans le même groupe ;
- en français/anglais LTR, trailing = droite et leading = gauche ; en arabe RTL, l'interface inverse automatiquement via `start/end`, jamais via `left/right` codés en dur ;
- un CTA directement rattaché à une carte ou à un rectangle se trouve **16 dp sous cet objet** et aligne son bord trailing sur le bord trailing du conteneur ;
- sur desktop, un bouton n'est pas étiré pleine largeur sans justification ;
- un pied d'action sticky est réservé aux tâches longues où l'action concerne l'ensemble de l'écran et doit rester disponible pendant le scroll. Il réserve sa hauteur dans le contenu et ne doit jamais masquer le focus. Ce pattern n'est pas utilisé uniquement pour remplir un grand vide.

Pour les écrans de résultat montrés lors de la revue du 26/09/2026, la cible attendue est donc : rectangle de résultat, `16 dp`, CTA trailing. Pour une confirmation précédée d'une case « J'ai compris », la case devient l'ancre immédiate du bouton : `16 dp`, puis CTA trailing.

## 4 bis.3 Contrat C - Component Anatomy

Les agents assemblent le langage Rewayah, ils ne redessinent pas les briques dans chaque feature.

Composants structurants déjà identifiés à préserver :

- `ActionPrincipale` pour tous les boutons ;
- `PageShell`, `PageParcours`, `PageImmersive` pour les gabarits ;
- `AppCard` pour une carte autonome ;
- `GroupeReglages` + `LigneRubrique` pour une carte groupée ;
- `StatusPill`, `SectionHeader`, `LigneCleValeur` pour les informations structurées ;
- `EtatSysteme`, `EcranResultat`, `EmptyState` pour les états ;
- `BlocAsynchrone` + `Skeleton` pour les chargements ;
- `OfflineBanner` pour la coupure réseau ;
- `LocalFeedback` pour le retour local ;
- `ConfirmDestructive` pour une confirmation destructive ;
- `AppBottomSheet` pour feuille/dialogue adaptatif.

Avant de créer un nouveau composant, l'agent prouve qu'aucun composant partagé ne couvre la responsabilité. Aucun fork local de `ActionPrincipale`, `AppCard`, `Skeleton`, `GroupeReglages` ou `AppBottomSheet` n'est accepté pour obtenir « juste ce rendu ».

Anatomies existantes à conserver :

- `AppCard` : rayon 16, filet, padding 20 sous 600 ou 24 au-delà, en-tête et actions espacés de 16 ;
- `GroupeReglages` : un seul rectangle, ligne minimale 48, icône 24, gap icône/libellé 12, padding 16 horizontal x 12 vertical, filet interne absent sous la dernière ligne ;
- `ActionPrincipale` : valeurs du §4 bis.2 ;
- `Skeleton` : blocs `surfaceSunken` qui reproduisent la forme du contenu final, sans shimmer, scintillement ou pulsation.

## 4 bis.4 Contrat D - Responsive Desktop

Le web est une vraie interface bureau. Il n'étire jamais mécaniquement le mobile.

Seuils déjà décidés pour les shells :

- compact sous 600 ;
- rail à partir de 600 lorsque le rôle le prévoit ;
- sidebar persistante à partir de 1200 lorsque le rôle le prévoit ;
- `AdminShell` : tiroir, rail 80, sidebar 288 selon largeur disponible.

Pour cette verticale à 1440 :

- sidebar admin : 288 ;
- padding de page : 32 de chaque côté ;
- largeur utile principale : 1088 ;
- composition master-detail recommandée : file 336, gap 24, détail 728 ;
- aucun troisième panneau obligatoire ; le viewer reste une surface dédiée/modal si nécessaire ;
- le détail ne s'étire pas au-delà de ce que le contenu exige ;
- hover, focus visible, clavier, molette et browser navigation sont des états de premier rang, pas des adaptations après coup.

Un écran qui n'a besoin que d'une colonne conserve une largeur de lecture/formulaire bornée par le composant ou le gabarit existant. L'agent ne crée pas une largeur maximale ad hoc dans chaque page.

## 4 bis.5 Contrat E - Interaction & Motion

Les valeurs existantes du dépôt sont gelées :

| Jeton | Valeur |
|---|---:|
| `retourTactile` | 100 ms |
| `micro` | 120 ms |
| `apparition` | 180 ms |
| `navigation` | 220 ms |
| `feuilleOuverture` | 180 ms |
| `feuilleFermeture` | 120 ms |
| plafond d'animation | 400 ms |
| pulsation exceptionnelle | 1200 ms, uniquement l'élément déjà autorisé |
| skeleton avant apparition | 180 ms |
| chargement prolongé | 8 s |
| requête considérée perdue | 20 s |

Courbes existantes : entrée `easeOutCubic`, sortie `easeInCubic`, ressort sans rebond, `linear` seulement pour une progression indéterminée. En réduction de mouvement : durée 0 et translation 0.

Tout contrôle interactif définit au minimum les états pertinents `default`, `hover`, `focus`, `pressed`, `disabled`, `loading`, `error`, `success/unavailable` selon son contrat. Les agents ne créent pas leur propre timing local pour hover, navigation, sheets ou feedback.

## 4 bis.6 Skeletons - retour obligatoire dans les vagues futures

Le système de skeleton existe déjà et a commencé à être utilisé. Il n'est **pas à redessiner**.

Règles :

1. `Skeleton` et `BlocAsynchrone` redeviennent obligatoires pour tout chargement initial substantiel dont la structure finale est connue ;
2. rien n'est affiché avant le délai existant de 180 ms afin d'éviter le flash ;
3. le skeleton reproduit la géométrie du contenu attendu, sans faux nom, fausse date, faux solde ou fausse donnée métier ;
4. à 8 s, le chargement prolongé est expliqué ; à 20 s, l'état devient récupérable selon `BlocAsynchrone` ;
5. le spinner seul au centre d'une page métier n'est pas le pattern de chargement ; un indicateur local reste permis dans un bouton ou une action ponctuelle ;
6. aucun shimmer, scintillement ou pulsation ne doit être ajouté : le composant existant est volontairement calme ;
7. la présence de skeletons est vérifiée dans les nouvelles fiches écran et dans la future passe d'harmonisation.

## 4 bis.7 Obligation de l'agent orchestrateur - mémoire et Suivi Rewayah

Dès réception de ce document, l'orchestrateur ne lance pas une refonte. Il exécute d'abord une **publication documentaire durable** :

1. retrouver `projet/ressources/LISEZ-MOI.md`, qui est le point d'entrée déclaré de la mémoire, des specs, des décisions et du registre des agents ;
2. retrouver la mémoire canonique active réellement référencée par ce fichier et y ajouter `DESIGN-GOV-2026-09-26` ; ne pas créer une deuxième mémoire concurrente ;
3. mettre à jour le document canonique UX actif, notamment `docs/current/03_DESIGN_SYSTEM_ET_UX.md` ou son remplaçant prouvé, avec les cinq contrats A à E et le rappel Skeleton ;
4. mettre à jour les instructions frontend actives (`lib/CLAUDE.md` ou leur remplaçant prouvé) pour obliger tout agent frontend à consulter cette décision avant un nouveau lot visuel ;
5. déposer la décision dans **Suivi Rewayah** comme `consigne du directeur`, puis créer les étapes nécessaires : publication des règles, contrôle par une seconde session, puis future harmonisation UI globale ;
6. conserver dans Suivi Rewayah la distinction `fait` puis `vérifié` avec preuve, conformément au mécanisme partagé ;
7. noter explicitement : **« règle gelée jusqu'à nouvelle décision datée du directeur »** ;
8. si le chemin réel de mémoire ou le suivi vivant diffère de la copie documentaire, utiliser la source vivante prouvée et consigner le chemin exact. Ne jamais inventer un nouveau registre pour contourner le système partagé.

Ces opérations sont documentaires et de coordination. Elles ne donnent aucune autorisation implicite de merge `main`, migration distante, déploiement production ou réécriture d'un lot terminé.

## 4 bis.8 Règle de progression - aucune marche arrière automatique

La gouvernance design a deux moments distincts :

**Maintenant :**

- figer les règles dans la mémoire, la Bible UX active et Suivi Rewayah ;
- utiliser ces règles dans toute **nouvelle spécification ou nouvelle maquette** produite à partir de cette décision ;
- continuer les rôles dans l'ordre prévu ;
- ne pas rouvrir une étape `fait` ou `vérifié` uniquement parce qu'elle ne respecte pas encore ces règles.

**Après implémentation des visuels de tous les rôles :**

- lancer une passe unique d'**harmonisation UI transversale** ;
- appliquer les contrats A à E et les skeletons aux écrans déjà construits ;
- traiter les écarts visuels consignés sans réinventer le métier ;
- exécuter golden tests, captures multi-format et vérification des composants partagés.

**Exception :** le directeur peut demander explicitement la correction immédiate d'un écran, d'un composant ou d'un lot précis. Cette demande doit être nommée dans Suivi Rewayah et ne devient pas une autorisation générale de reprendre les autres étapes.

**Exemple obligatoire à conserver dans la mémoire :** le lot **Tuteur - compléments** est considéré comme visuellement insuffisant sur plusieurs points. Il est enregistré comme dette d'harmonisation, mais **on ne fait pas marche arrière maintenant**. Aucun reset, aucune réouverture générale de la vague Tuteur, aucune refonte de tous ses écrans avant de poursuivre les autres rôles. Le projet avance, puis la passe transversale corrige l'ensemble avec une même grammaire.

---

# 5. Fiche du rôle pour cette verticale

## 5.1 Utilisateur

Utilisateur principal : membre du personnel administratif autorisé à traiter des dossiers.

Contexte :

- utilisation fréquente sur ordinateur ;
- possibilité d'usage tablette ;
- usage mobile possible mais secondaire ;
- tâches répétitives, sensibles et à faible tolérance à l'erreur ;
- données personnelles et documents d'identité ;
- besoin de travailler rapidement sans sacrifier la vérification.

## 5.2 Tâches principales

Ordre de priorité :

1. identifier le prochain dossier réellement prêt à être revu ;
2. lire les informations nécessaires et la pièce déposée ;
3. exécuter les trois vérifications métier existantes ;
4. valider le dossier si le serveur confirme tous les prérequis ;
5. refuser avec un motif exploitable par la personne concernée si le dossier ne peut pas être accepté.

## 5.3 Ce que l'administrateur ne doit jamais voir ici

Cet écran ne doit pas devenir une fiche globale de la personne.

Ne pas afficher dans `ADM-02` :

- paiement du foyer ;
- solde ;
- coordonnées d'autres membres du foyer ;
- notes pédagogiques ;
- détails de classes non nécessaires à la validation ;
- télémétrie de visio ;
- identifiants techniques de stockage ;
- URL brute d'un objet R2 ;
- jeton de lecture de pièce ;
- secrets Supabase ;
- données d'un dossier non autorisé ;
- journal d'audit complet ;
- données internes sans rapport direct avec la décision.

Pour voir l'historique global d'une personne après décision, l'administration utilise le registre `ADM-08 Comptes`, pas `ADM-02`.

---

# 6. Navigation

Cette verticale n'invente aucune nouvelle destination principale.

Navigation admin existante à préserver :

- Accueil
- Opérations
- Personnes
- Pédagogie
- Finance
- Configuration
- Sécurité et audit
- Direction, seulement si la capacité existe réellement

Destination active pour `ADM-02` : **Personnes**.

## 6.1 Entrées autorisées

Entrée principale :

`Administration > Personnes > Dossiers à valider`

Raccourci autorisé :

`Accueil admin > compteur Dossiers à valider`

Les deux entrées ouvrent le même flux et la même route canonique.

## 6.2 Sorties

Depuis `ADM-02` :

- retour vers le centre de commande ;
- navigation vers les autres domaines via la coquille admin ;
- retour au prochain dossier après décision ;
- accès à `/compte/profil` uniquement si un prérequis personnel réel bloque la revue ;
- accès à `ADM-08 Comptes` seulement via la navigation normale, jamais comme doublon de la file.

---

# 7. Carte des fonctions, anti-doublon

| Fonction | Écran unique | Route / surface | Emplacement | Point d'entrée |
|---|---|---|---|---|
| Voir les dossiers prêts à être revus | ADM-02A | `/admin/personnes/dossiers` | colonne ou liste de file | Personnes, compteur Accueil |
| Ouvrir un dossier | ADM-02A -> ADM-02B | même route avec sélection stable ou route de détail existante si déjà présente | sélection dans la file | ligne du dossier |
| Voir les informations nécessaires | ADM-02B | détail du dossier | bloc Identité et dossier | dossier sélectionné |
| Voir la pièce déposée | ADM-02C | viewer local sécurisé | panneau document | action `Voir la pièce` |
| Exécuter les trois vérifications | ADM-02B | détail du dossier | bloc Vérifications | dossier sélectionné |
| Valider le dossier | ADM-02B + confirmation ADM-02E | même flux | zone décision fixe | bouton `Valider le dossier` |
| Refuser le dossier | ADM-02B + feuille ADM-02D | même flux | zone décision fixe | bouton `Refuser le dossier` |
| Renseigner un prérequis personnel admin | `/compte/profil` | écran partagé existant | profil personnel | dépendance affichée dans ADM-02 |
| Voir les comptes déjà décidés | ADM-08 | `/admin/personnes/comptes` | registre existant | navigation Personnes / Outils |

Aucun historique de dossiers décidés n'est créé dans `ADM-02`.

Aucun second écran de profil admin n'est créé.

Aucun second stockage KYC n'est créé.

---

# 8. Parcours de bout en bout

## P-ADM-01 - Ouvrir la file depuis Personnes

1. L'administrateur ouvre le domaine Personnes.
2. `Dossiers à valider` est la destination active.
3. Le serveur charge uniquement les dossiers accessibles à cet administrateur et prêts pour revue.
4. Si des dossiers existent, le premier élément peut être sélectionné automatiquement sur desktop seulement.
5. Sur mobile, aucune sélection automatique ne pousse l'utilisateur dans un dossier sans action. La liste reste visible.
6. L'administrateur ouvre un dossier.
7. Le détail charge ses données indépendamment de la liste.
8. Le retour restaure la position et les filtres de la file.

## P-ADM-02 - Ouvrir depuis le compteur Accueil

1. L'administrateur touche ou clique `Dossiers à valider`.
2. Le système ouvre `/admin/personnes/dossiers`.
3. La file utilise le même état que l'entrée par Personnes.
4. Aucun écran parallèle n'est créé.

## P-ADM-03 - Revoir un dossier enseignant

1. L'administrateur ouvre un dossier de type Enseignant.
2. L'écran montre le rôle, l'identité nécessaire, l'état du dossier et les éléments réellement soumis.
3. La pièce d'identité est ouverte dans le viewer sécurisé.
4. L'administrateur revient au dossier sans perdre sa progression.
5. Les trois vérifications métier existantes sont renseignées ou confirmées selon le contrat réel.
6. `Valider le dossier` reste indisponible tant que le serveur ne considère pas le dossier validable.
7. L'administrateur demande la validation.
8. Une confirmation explicite résume la conséquence.
9. Le client envoie une seule commande serveur idempotente avec version attendue du dossier.
10. Le succès n'est affiché que si le serveur confirme la nouvelle situation.
11. Le dossier disparaît de la file active.
12. L'écran sélectionne le dossier suivant sur desktop, ou revient à la file sur mobile.
13. Le parcours enseignant est ensuite géré par `04_ENSEIGNANT.md`. `03` ne choisit pas silencieusement sa page d'atterrissage.

## P-ADM-04 - Refuser un dossier

1. L'administrateur ouvre un dossier.
2. Il choisit `Refuser le dossier`.
3. Une feuille ou un dialogue demande le motif.
4. Le motif est obligatoire.
5. Le texte est rédigé pour pouvoir être affiché dans le portail d'attente, car l'état refusé montre un motif serveur.
6. La commande de refus n'est envoyée qu'après confirmation.
7. Le succès n'est annoncé que si le serveur confirme la décision.
8. Le dossier quitte la file active.
9. Le portail d'attente de la personne reçoit l'état refusé et le motif selon le mécanisme existant.
10. Aucun message `E-mail envoyé` ou `Notification envoyée` n'est affiché tant qu'un service réel ne le garantit.

## P-ADM-05 - Dossier déjà traité par un autre administrateur

1. Deux administrateurs peuvent avoir chargé le même dossier.
2. Le premier prend une décision.
3. Le second tente une action avec une version devenue obsolète.
4. Le serveur refuse la commande par conflit de version ou état déjà décidé.
5. L'UI affiche : `Ce dossier a été traité par un autre membre de l'équipe.`
6. Action : `Actualiser le dossier`.
7. Aucune seconde décision n'est envoyée automatiquement.

## P-ADM-06 - Pièce inaccessible

1. Le dossier charge.
2. Le document privé ne peut pas être lu ou l'URL signée a expiré.
3. Le bloc pièce affiche l'erreur sans faire tomber toute la page.
4. Action : `Recharger la pièce`.
5. La validation reste désactivée si la lecture est nécessaire à une vérification. Le refus suit sa propre autorisation serveur ; une pièce illisible ne doit pas empêcher un refus autorisé.
6. Aucune URL brute ou erreur de stockage n'est exposée.

## P-ADM-07 - Politique de genre KYC

1. ADM-02 lit la politique effective côté serveur avec les capabilities du reviewer.
2. Si `genre_reviewer_enforced=false`, aucun blocage, filtrage ou message lié au genre n'est affiché ; la file dépend seulement des autres permissions et du périmètre autorisé.
3. Si `genre_reviewer_enforced=true`, le serveur applique la règle de genre réellement existante et vérifiée dans le dépôt.
4. Si cette politique active exige une donnée de profil absente, ADM-02 affiche un état bloquant clair.
5. Texte : `Votre profil doit être complété avant de consulter les dossiers autorisés par cette règle.`
6. Action : `Compléter mon profil`.
7. L'action ouvre `/compte/profil` ou la procédure sûre existante ; aucun formulaire de genre n'est dupliqué dans ADM-02.
8. Un reviewer ordinaire ne peut pas activer/désactiver la politique. Le changement appartient à la configuration Super Admin et est audité.
9. Après changement de politique ou correction autorisée du profil, la file est relue depuis le serveur.

---

# 9. Écran ADM-02A - Dossiers à valider

**Identifiant :** ADM-02A  
**Nom visible :** Dossiers à valider  
**Route canonique :** `/admin/personnes/dossiers`  
**Écran parent :** domaine Personnes ou Accueil admin  
**Destination active :** Personnes

## 9.1 Objectif unique

Permettre à l'administrateur de choisir le prochain dossier réellement prêt à être revu.

## 9.2 Action principale

Aucune action pleine persistante.

L'interaction principale est la sélection d'un dossier dans la file.

## 9.3 Actions secondaires

- filtrer si le volume le justifie ;
- actualiser ;
- ouvrir un dossier.

## 9.4 Disposition mobile, 390 x 844

AdminShell en mode tiroir.

Ordre :

1. en-tête de page `Dossiers à valider` ;
2. sous-texte `Examinez les dossiers prêts pour une décision.` ;
3. compteur textuel si le serveur fournit un total fiable, format `12 dossiers en attente` ;
4. filtres compacts si utiles ;
5. liste groupée unique ;
6. chaque ligne montre seulement :
   - prénom et nom ;
   - type de dossier, `Enseignant` ou libellé réel du rôle ;
   - ancienneté lisible si fournie ;
   - état technique utile, jamais code interne ;
   - chevron ;
7. retour et coquille admin toujours accessibles.

Aucune grande carte par dossier.

Une seule carte groupée avec filets internes.

## 9.5 Disposition tablette, 768

Rail admin.

PROPOSITION : à 768 dp, rail 80 et marges 24 de chaque côté laissent 640 dp. Utiliser liste puis détail. Deux panneaux seulement si la largeur utile permet 320 dp de file, 32 dp de séparation et au moins 480 dp de détail, sans troncature au niveau de texte actif. Le shell suit les points de rupture existants ; le contenu suit la place réellement disponible.

## 9.6 Disposition ordinateur, 1440

Barre latérale admin 288.

Vraie version bureau.

PROPOSITION validable selon standards 2026 :

- zone de contenu avec respiration 32 ;
- colonne file entre 320 et 360 ;
- détail sélectionné occupe le reste ;
- aucun contenu principal étiré au-delà d'une largeur lisible ;
- filtres en ligne avec cibles souris, hauteur compacte conforme au design system ;
- hover sur lignes ;
- focus clavier visible ;
- flèches clavier seulement si un pattern existant le supporte ;
- Tab traverse filtres, file et actions ;
- pas de boutons 72 dp conçus pour le pouce.

## 9.7 Textes visibles

Titre : `Dossiers à valider`

Sous-titre : `Examinez les dossiers prêts pour une décision.`

Chargement : `Chargement des dossiers…`

Vide : `Aucun dossier n'attend de validation.`

Aide vide : `Les nouveaux dossiers apparaîtront ici lorsqu'ils seront prêts.`

Erreur : `Impossible de charger les dossiers.`

Action erreur : `Réessayer`

Hors ligne : `Vous êtes hors ligne. Les dossiers ne peuvent pas être actualisés.`

Action : `Réessayer`

Permission refusée : `Vous n'avez pas accès aux dossiers à valider.`

Filtre rôle, PROPOSITION si utile : `Type de dossier`

Options : utiliser uniquement les valeurs réellement supportées par le serveur.

Aucune valeur fictive n'est ajoutée.

## 9.8 États

- chargement initial ;
- contenu ;
- vide ;
- erreur globale ;
- hors ligne ;
- permission refusée ;
- actualisation ;
- filtre sans résultat ;
- dossier devenu indisponible après chargement ;
- dépendance de profil liée au genre, uniquement si la politique Super Admin est active et que le serveur l'exige.

## 9.9 Données

CONTRAT À VÉRIFIER, OU PORT À SPÉCIFIER SI ABSENT : `list_reviewable_dossiers`

Entrée :

- curseur ;
- filtre de type si supporté ;
- limite ;
- identité admin déduite de la session, jamais envoyée comme permission client.

Sortie minimale :

- `dossier_id`
- `subject_display_name`
- `subject_role`
- `submitted_at`
- `review_status`
- `revision`
- `has_identity_document`
- total ou `has_more` si disponible

Ne pas livrer le document complet dans la liste.

## 9.10 Critères d'acceptation

- Étant donné un admin autorisé, quand il ouvre Personnes puis `Dossiers à valider`, alors la file réelle s'affiche.
- Étant donné aucun dossier, alors aucun faux dossier de démonstration n'apparaît en production.
- Étant donné 200 % de texte, alors aucune ligne importante n'est tronquée sans accès au contenu.
- Étant donné un clic sur un dossier, alors le détail du même `dossier_id` s'ouvre.
- Étant donné un retour, alors position et filtres sont restaurés.

## 9.11 Références UX à valider

- Flutter adaptive/responsive ;
- Material 3 ;
- WCAG 2.2 AA ;
- Nielsen, visibilité d'état ;
- Jakob, conventions de liste bureau ;
- Fitts pour cibles souris et tactiles selon format.

---

# 10. Écran ADM-02B - Revue du dossier

**Identifiant :** ADM-02B  
**Nom visible :** Dossier de {prénom} {nom}  
**Route :** conserver la route existante si le code sélectionne un dossier localement. Si une route de détail existe déjà, la réutiliser. Ne pas créer un doublon sans besoin.  
**Parent :** ADM-02A  
**Destination active :** Personnes

## 10.1 Objectif unique

Réunir les éléments strictement nécessaires pour prendre une décision fiable sur un dossier.

## 10.2 Action principale

`Valider le dossier`

## 10.3 Action secondaire sensible

`Refuser le dossier`

Le refus ne doit pas avoir le même poids visuel que l'action principale.

## 10.4 Disposition mobile

Ordre :

1. retour vers la file ;
2. en-tête avec nom et type de dossier ;
3. statut actuel ;
4. carte groupée `Identité et dossier` ;
5. carte groupée `Pièce d'identité` ;
6. carte groupée `Vérifications` ;
7. carte groupée `Accords et éléments soumis` uniquement si les données existent ;
8. action group placé 16 dp après le dernier bloc décisionnel auquel il se rapporte ;
9. `Refuser le dossier` action destructive secondaire ;
10. `Valider le dossier` action principale, au trailing du groupe.

Sur mobile uniquement, ce groupe peut devenir sticky si la revue est suffisamment longue pour que l'action doive rester disponible pendant le scroll. Dans ce cas, il concerne l'ensemble du dossier, réserve sa hauteur dans le contenu et ne masque ni focus ni clavier. Il n'est jamais collé en bas seulement pour remplir l'écran.

Éviter de garder le document d'identité grand ouvert dans le flux vertical. L'ouverture du document se fait dans ADM-02C.

## 10.5 Disposition tablette

Deux zones seulement si la largeur le permet :

- contenu du dossier ;
- panneau décision ou document.

À 200 %, repasser en colonne.

## 10.6 Disposition ordinateur 1440

PROPOSITION : à 1440 dp, sidebar 288 et marges 32 de chaque côté laissent 1088 dp.

- file de 336 dp, gouttière 24 dp, détail de 728 dp ;
- pièce ouverte sur demande dans ADM-02C, jamais troisième colonne obligatoire ;
- décision dans le panneau détail, en un seul emplacement, 16 dp après le dernier bloc décisionnel, action group aligné trailing ;
- trois colonnes seulement si leur largeur totale tient réellement, sans dépasser le gabarit de gestion ; elles ne sont pas nécessaires à ce lot ;
- texte agrandi : repli séquentiel dès que les largeurs minimales ne tiennent plus ;
- les marges utilisent les jetons gelés, les dimensions de colonnes sont des contraintes de composition proposées ;
- conserver `ActionPrincipale` et ses cibles, pas de nouveaux boutons compactés sous les minimums du système.

## 10.7 Carte `Identité et dossier`

Un seul rectangle.

Lignes séparées par filets.

Afficher uniquement les champs réellement disponibles et nécessaires.

Libellés possibles selon données réelles :

- `Nom`
- `Prénom`
- `Type de dossier`
- `Date de dépôt`
- `État du dossier`

Si une donnée n'est pas fournie, ne pas inventer `Non renseigné` pour une donnée obligatoire. Utiliser un état bloquant si le serveur considère la donnée obligatoire.

## 10.8 Carte `Pièce d'identité`

Titre : `Pièce d'identité`

Contenu :

- type de pièce ;
- état de disponibilité ;
- aperçu neutre si autorisé ;
- action `Voir la pièce`.

Aucun chemin de stockage.

Aucune taille de bucket.

Aucune clé R2.

Aucun lien copiable exposant un token.

## 10.9 Carte `Vérifications`

Titre : `Vérifications`

Les trois vérifications existantes sont affichées dans l'ordre exact du code courant.

Chaque ligne comprend :

- libellé exact existant ;
- état ;
- contrôle ou indication appropriée ;
- éventuelle aide existante.

**AUCUN LIBELLÉ N'EST INVENTÉ DANS CE DOCUMENT.**

Claude remplit les textes exacts après lecture du code/i18n dans le journal du lot.

Si ces vérifications sont des cases administratives, elles ne sont jamais précochées localement.

Si elles sont calculées serveur, le frontend ne permet pas de les modifier.

## 10.10 Carte `Accords et éléments soumis`

Afficher seulement les preuves réellement disponibles :

- accusé de la notice ;
- contrat du rôle ;
- pièce reçue.

Ne pas reproduire le contrat intégral si un écran ou document dédié existe.

Utiliser un statut factuel.

Ne pas écrire `Signé` si le serveur ne fournit pas une acceptation versionnée.

## 10.11 Textes visibles

Titre dynamique : `Dossier de {prénom} {nom}`

Type : `Enseignant` ou valeur serveur traduite.

Section : `Identité et dossier`

Section : `Pièce d'identité`

Action : `Voir la pièce`

Section : `Vérifications`

Section optionnelle : `Accords et éléments soumis`

Action principale : `Valider le dossier`

Action secondaire : `Refuser le dossier`

Si validation impossible : `Ce dossier n'est pas encore prêt à être validé.`

Si détail indisponible : `Impossible de charger ce dossier.`

Action : `Réessayer`

Si déjà traité : `Ce dossier a déjà été traité.`

Action : `Retour aux dossiers`

Si traité ailleurs pendant la revue : `Ce dossier a été traité par un autre membre de l'équipe.`

Action : `Actualiser le dossier`

## 10.12 États

- chargement ;
- contenu nominal ;
- document en chargement ;
- document indisponible ;
- vérifications incomplètes ;
- accords manquants ;
- dossier non validable serveur ;
- décision en cours ;
- conflit concurrent ;
- dossier déjà décidé ;
- erreur de page ;
- permission refusée ;
- hors ligne ;
- prérequis admin manquant ;
- capacité serveur de décision indisponible.

## 10.13 Données

CONTRAT À VÉRIFIER, OU PORT À SPÉCIFIER SI ABSENT : `get_dossier_for_review`

Entrée :

- `dossier_id`

Sortie minimale :

- `dossier_id`
- `revision`
- identité minimale autorisée
- `subject_role`
- `submitted_at`
- `review_status`
- référence sécurisée vers la pièce
- type de pièce
- états des trois vérifications
- acceptations requises et versions si disponibles
- `can_validate`
- `validation_blockers[]`

Le serveur décide `can_validate`.

Le client ne reconstruit pas cette décision avec trois booléens locaux.

## 10.14 Critères d'acceptation

- Étant donné un dossier sélectionné, quand le détail est chargé, alors aucune donnée d'un autre dossier n'apparaît.
- Étant donné une pièce indisponible, alors `Valider le dossier` ne devient pas actif si le serveur exige cette pièce.
- Étant donné une vérification non satisfaite, alors le client n'autorise pas la validation si `can_validate=false`.
- Étant donné un dossier stale, alors le client ne remplace pas silencieusement la décision.
- Étant donné un admin sans permission, aucune donnée sensible n'est rendue.

---

# 11. Surface ADM-02C - Viewer sécurisé de pièce

**Identifiant :** ADM-02C  
**Nom visible :** Pièce d'identité  
**Type :** viewer local, modal plein écran ou panneau selon format  
**Parent :** ADM-02B

## 11.1 Objectif unique

Permettre la lecture de la pièce sans exposer son emplacement technique.

## 11.2 Disposition mobile

Plein écran focalisé :

- retour ;
- titre `Pièce d'identité` ;
- type de pièce ;
- zone d'image ou document ;
- zoom contrôlé ;
- action `Fermer`.

Pas de navigation globale au-dessus du document si elle réduit dangereusement la lisibilité.

## 11.3 Tablette

Viewer plein écran ou grand dialogue.

## 11.4 Desktop

Grand panneau ou dialogue centré avec :

- largeur suffisante ;
- fond neutre ;
- zoom ;
- rotation uniquement si le composant existant la supporte ;
- aucun téléchargement si ce droit n'est pas explicitement prévu ;
- focus piégé dans le dialogue ;
- Échap ferme le viewer si aucune action sensible n'est en cours.

## 11.5 Textes

Titre : `Pièce d'identité`

Chargement : `Chargement de la pièce…`

Erreur : `La pièce ne peut pas être affichée.`

Action : `Réessayer`

Action : `Fermer`

Lien expiré : `L'accès à cette pièce a expiré.`

Action : `Recharger la pièce`

## 11.6 Sécurité

- URL signée courte si l'architecture l'utilise ;
- pas de token dans logs ;
- pas de persistance locale non nécessaire ;
- pas de copie dans le bucket public ;
- pas d'image dans Sentry ;
- pas de données sensibles dans breadcrumbs ;
- réponse sensible sans cache persistant contrôlé par l’application ; vérifier les en-têtes de cache du service et exclure ces réponses du service worker ;
- RLS pour les données Supabase et contrôle d’accès serveur pour R2 ; une RLS Supabase ne protège pas à elle seule un objet R2 ;
- aucun viewer public autonome. Une URL présignée est un secret porteur temporaire, observable par le navigateur qui la reçoit : ne jamais la placer dans l’interface, la navigation, les logs ou la télémétrie.

## 11.7 Critères d'acceptation

- Étant donné une pièce autorisée, quand l'admin ouvre le viewer, alors le document est lisible.
- Étant donné un token expiré, alors l'UI récupère une nouvelle autorisation sans révéler l'ancienne URL.
- Étant donné une fermeture, alors le focus revient à `Voir la pièce`.
- Étant donné un rôle non autorisé, alors aucun contenu du viewer n'est livré.

---

# 12. Surface ADM-02D - Refuser le dossier

**Identifiant :** ADM-02D  
**Nom visible :** Refuser le dossier  
**Type :** bottom sheet mobile, dialogue tablette et desktop  
**Parent :** ADM-02B

## 12.1 Objectif unique

Recueillir un motif clair avant une décision de refus.

## 12.2 Texte

Titre : `Refuser le dossier`

Corps : `Indiquez le motif qui sera affiché à la personne concernée.`

Champ : `Motif du refus`

Aide : `Expliquez ce qui doit être corrigé, sans donnée interne ni commentaire personnel.`

Erreur vide : `Indiquez le motif du refus.`

Action secondaire : `Annuler`

Action destructive : `Refuser le dossier`

Envoi : `Refus en cours…`

Erreur serveur : `Le dossier n'a pas pu être refusé.`

Action : `Réessayer`

Conflit : `Ce dossier a été traité par un autre membre de l'équipe.`

Action : `Actualiser le dossier`

## 12.3 Règles

Le motif est obligatoire.

Ne pas ajouter une taxonomie de motifs tant qu'elle n'existe pas dans le contrat.

Ne pas créer de note interne dans ce lot.

Ne pas écrire de motif automatique.

Ne pas inclure de détail médical, financier ou autre donnée non nécessaire.

## 12.4 Critères d'acceptation

- Étant donné un champ vide, quand l'admin tente de confirmer, alors le refus n'est pas envoyé.
- Étant donné un motif valide, quand le serveur confirme, alors le dossier quitte la file.
- Étant donné une erreur serveur, alors le motif saisi reste disponible pour reprise.
- Étant donné un conflit, alors aucune seconde décision n'est envoyée.

---

# 13. Surface ADM-02E - Confirmer la validation

**Identifiant :** ADM-02E  
**Nom visible :** Valider le dossier  
**Type :** dialogue de confirmation  
**Parent :** ADM-02B

## 13.1 Objectif unique

Éviter une validation accidentelle et rappeler la conséquence réelle.

## 13.2 Texte

Titre : `Valider ce dossier ?`

Corps, selon la conséquence confirmée par le contrat :

- validation avec activation possible : `Le dossier de {nom} sera validé. Son compte pourra accéder à son espace.` ;
- validation documentaire seule : `Le dossier de {nom} sera validé. Les autres conditions d’accès resteront applicables.`.

Afficher le type de dossier et les blocages d’accès connus. Si la conséquence n’est pas déterminable, ne pas ouvrir une confirmation trompeuse : afficher `La validation est indisponible pour le moment.`.

Ne pas promettre une notification.

Ne pas promettre une affectation de classe.

Ne pas promettre l'activation d'une photo publique.

Action secondaire : `Annuler`

Action principale : `Valider le dossier`

Envoi : `Validation en cours…`

Erreur : `Le dossier n'a pas pu être validé.`

Action : `Réessayer`

## 13.3 Règle atomique

La décision, ses vérifications et sa trace d’audit sont atomiques côté serveur. L’accès reste un état distinct : une validation KYC ne lève jamais implicitement une suspension, un blocage financier ou un autre prérequis. Si le contrat active le compte dans cette même commande, cet effet doit être atomique ; sinon afficher le dossier validé et le blocage d’accès réel séparément.

Le frontend ne doit pas :

1. marquer le dossier validé ;
2. puis exécuter une deuxième mutation indépendante pour rendre le compte actif ;
3. puis afficher un succès si la deuxième mutation échoue.

Si le backend actuel sépare ces actions, Claude doit documenter la dépendance et empêcher un faux succès.

## 13.4 Critères d'acceptation

- Étant donné `can_validate=false`, le dialogue ne peut pas être ouvert par un bouton actif.
- Étant donné un clic accidentel, `Annuler` ne modifie rien.
- Étant donné une réponse serveur confirmée, alors seulement l'UI affiche le succès.
- Étant donné un timeout sans résultat déterminable, l'UI n'affirme pas que le dossier est validé.

---

# 14. État de décision réussie

Il n'y a pas de page de succès autonome.

Une page autonome ajouterait une étape inutile dans un travail répétitif.

Comportement proposé :

- toast ou feedback non bloquant `Dossier validé.` ou `Dossier refusé.` seulement après confirmation serveur ;
- retrait du dossier de la file ;
- sélection du suivant sur desktop ;
- retour à la liste sur mobile ;
- compteur admin actualisé depuis le serveur.

Ne jamais afficher :

- `E-mail envoyé`
- `Notification envoyée`
- `Compte activé`
- `Enseignant prêt`
- `Classe attribuée`

sans réponse serveur qui garantit exactement cette conséquence.

---

# 15. Politique de genre pour la revue KYC

## 15.1 Décision du directeur

La contrainte de genre de la revue KYC reste disponible, mais elle devient une **politique configurable par Super Admin**.

Deux états serveur :

- `genre_reviewer_enforced = true` : le serveur applique la règle de genre existante, après que Claude en a retrouvé et testé le comportement exact ;
- `genre_reviewer_enforced = false` : aucun filtrage ou refus d'accès ne peut être fondé sur le genre du reviewer ou du dossier. Tout reviewer disposant de la capability KYC et du périmètre requis peut revoir le dossier.

L'UI ne décide jamais localement de cette politique.

## 15.2 Configuration Super Admin

Le point de configuration vit dans la surface canonique de configuration/sécurité du Super Admin lorsqu'elle existe. Ne pas ajouter le toggle dans ADM-02.

Libellé proposé : `Limiter la revue KYC selon le genre`

Aide : `Lorsque cette règle est désactivée, tout membre autorisé à revoir les dossiers peut traiter les dossiers de son périmètre, quel que soit son genre.`

La modification exige :

- capability Super Admin dédiée ou équivalente prouvée ;
- mutation serveur ;
- audit de l'acteur, ancienne valeur, nouvelle valeur et date serveur ;
- actualisation des files ouvertes ;
- aucun élargissement de droits au-delà du périmètre KYC déjà autorisé.

## 15.3 Profil du reviewer

Quand la politique est désactivée, un genre absent dans le profil ne bloque pas ADM-02.

Quand la politique est activée, Claude conserve le comportement réel du serveur. Si le serveur exige le genre et qu'il manque, la correction passe par l'unique profil partagé ou par une procédure administrative sûre. Un reviewer ne peut jamais modifier librement ce champ dans le but d'obtenir davantage de dossiers.

Dans ADM-02, si un prérequis personnel réellement imposé par la politique active manque :

Titre : `Profil à compléter`

Texte : `Votre profil doit être complété avant de consulter les dossiers autorisés par cette règle.`

Action : `Compléter mon profil`

Retour après succès : `/admin/personnes/dossiers`

Aucun formulaire duplicatif dans ADM-02.

## 15.4 Tests obligatoires

- politique active, reviewer conforme à la règle existante : accès selon capability et périmètre ;
- politique active, reviewer non conforme : refus serveur ;
- politique active, genre manquant : comportement serveur explicite et UI récupérable ;
- politique désactivée, reviewer homme : mêmes capacités KYC que son périmètre autorisé ;
- politique désactivée, reviewer femme : mêmes capacités KYC que son périmètre autorisé ;
- reviewer ordinaire : impossible de changer la politique ;
- Super Admin autorisé : changement audité et pris en compte sans redéploiement client ;
- politique modifiée pendant qu'une file est ouverte : prochain refresh relit la règle serveur ; aucune ancienne autorisation locale n'est conservée comme vérité.

---

# 16. Règles de confidentialité et sécurité

## 16.1 Séparation des identités

Une pièce KYC n'est jamais :

- photo de profil ;
- photo publique enseignant ;
- vignette de Classe ;
- portrait d'élève ;
- pièce jointe de messagerie ;
- ressource de bibliothèque.

## 16.2 Moindre privilège

L'API de revue ne retourne que les champs nécessaires.

L'administration n'accède pas aux pièces par un bucket public.

Chaque lecture et mutation exige une capacité administrative de revue prouvée côté serveur, un compte autorisé et le périmètre du dossier. Aucun rôle enseignant, tuteur, élève, contrôleur ou comptable ne reçoit cette capacité par ce document. Un intitulé « admin » seul ne suffit pas. La consultation de son propre dépôt utilise son contrat personnel, jamais ce contrat de revue.

## 16.3 Audit

Chaque décision doit créer ou utiliser une trace serveur avec au minimum :

- dossier ;
- décision ;
- acteur autorisé ;
- date serveur ;
- version du dossier ;
- motif si refus ;
- résultat.

Ne pas journaliser le contenu de la pièce.

Ne pas journaliser le token de lecture. Le motif public est conservé uniquement dans les données métier et l’audit autorisés nécessaires, jamais dans la télémétrie générale. La politique de conservation existante reste applicable ; ce lot ne crée ni durée illimitée ni nouvelle règle de suppression.

## 16.4 Concurrence

Toute mutation sensible utilise :

- version attendue ;
- état attendu ;
- idempotence démontrée par le contrat existant, sinon identifiant de commande stable à spécifier comme dépendance backend. Aucune décision sensible ne part dans une file hors ligne.

Erreur type : `stale_dossier`.

## 16.5 Déconnexion et retour

Une déconnexion ferme l'accès aux données immédiatement.

Purger les états, images en mémoire et caches contrôlés par l’application lors de la déconnexion ou perte de capacité. Le retour navigateur exige une nouvelle vérification de session avant rendu. Une URL présignée déjà émise peut rester utilisable jusqu’à son expiration ; ne pas promettre sa révocation immédiate sans mécanisme serveur démontré. Le frontend ne peut pas retirer les octets déjà copiés par un destinataire autorisé.

---

# 17. Contrats serveur proposés

Les noms sont des PROPOSITIONS de contrat, pas un mandat de créer des RPC. Claude doit préférer les RPC/services existants s’ils couvrent déjà le besoin. Toute implémentation backend manquante est un lot explicite, selon le mandat applicable et les autorisations en vigueur.

## 17.1 `list_reviewable_dossiers`

Entrée :

- curseur ;
- limite ;
- filtre de rôle optionnel, seulement si supporté.

Sortie :

- éléments minimaux de file ;
- curseur suivant ;
- nombre total si fiable.

Erreurs :

- unauthorized ;
- forbidden ;
- temporarily_unavailable.

## 17.2 `get_dossier_for_review`

Entrée :

- dossier_id.

Sortie :

- détail minimal ;
- état ;
- version ;
- référence document ;
- vérifications avec identifiant stable, origine, caractère obligatoire, état et possibilité de modification ;
- accords applicables au rôle et à la politique effective ;
- version du document et révision du dossier ;
- `can_validate`, `can_reject`, `can_view_document`, `can_resubmit` selon surface autorisée ;
- blocages distincts de validation, refus et accès ;
- conséquence de la décision, issue du contrat existant.

Erreurs :

- not_found ;
- forbidden ;
- stale ;
- temporarily_unavailable.

## 17.3 `request_kyc_document_view`

Entrée :

- dossier_id ;
- document_id.

Sortie :

- URL temporaire ou handle sécurisé ;
- expiration ;
- type MIME autorisé.

Erreurs :

- forbidden ;
- expired ;
- not_found ;
- unsupported_type ;
- temporarily_unavailable.

## 17.4 `decide_dossier`

Entrée :

- dossier_id ;
- expected_revision ;
- decision `approved|rejected` ;
- expected_review_status et expected_document_revision lorsque nécessaires au contrat ;
- command_id stable, ou mécanisme équivalent d’idempotence démontré ;
- preuves des contrôles humains, ou références à leurs états déjà persistés côté serveur ;
- rejection_reason nullable uniquement si approved, motif non vide après suppression des espaces si rejected.

Sortie :

- final_review_status ;
- access_state si la commande est responsable de l'accès ;
- new_revision ;
- decided_at ;
- audit_event_id si exposable sans risque.

Erreurs :

- forbidden ;
- stale_dossier ;
- already_decided ;
- missing_required_check ;
- missing_required_acceptance ;
- document_unavailable ;
- cannot_activate ;
- temporarily_unavailable.

Règle : la réponse distingue décision et accès réellement acquis. À l’exécution, le serveur recontrôle session, capacité, périmètre, révisions, état, vérifications et accords. `can_validate` lu auparavant ne vaut pas autorisation définitive. Une décision et son audit ne peuvent être partiellement enregistrés.


### 17.5 `get_kyc_review_policy` / `set_kyc_review_policy`

Capacité cible, à mapper sur les contrats réels avant création.

Lecture :

```text
get_kyc_review_policy()
-> {
     genre_reviewer_enforced,
     updated_at,
     can_update
   }
```

Mutation Super Admin :

```text
set_kyc_review_policy(
  genre_reviewer_enforced,
  expected_version
)
-> {
     genre_reviewer_enforced,
     version,
     updated_at
   }
```

Règles :

- la lecture de la politique n'accorde aucune capability de revue ;
- la mutation est réservée au Super Admin autorisé ;
- toute mutation est auditée ;
- si `genre_reviewer_enforced=false`, les services de liste, lecture de pièce et décision ne filtrent pas selon le genre ;
- si `true`, ils appliquent la règle réellement existante et testée ;
- aucun cache Flutter ne devient source de vérité pour cette autorisation.

### 17.6 Vérifications et reprise, contrats à raccorder

Si les contrôles sont humains, réutiliser la commande réelle de persistance ou les transmettre avec la décision atomique. Si elle manque, **PROPOSITION de port** `save_review_checks(dossier_id, expected_revision, document_revision, checks, command_id)` : renvoie la nouvelle révision, les contrôles persistés, `can_validate` et les blocages ; erreurs forbidden, stale_dossier, invalid_check, temporarily_unavailable. Aucun contrôle serveur calculé n’est éditable. Un changement de pièce ou de révision oblige à recharger les preuves et à refaire les contrôles devenus obsolètes selon le contrat métier.

Pour un résultat incertain, réutiliser une lecture autorisée de commande ou spécifier `get_decision_result(dossier_id, command_id)` : pending, succeeded avec résultat, failed, unknown. Le serveur contrôle le périmètre. Si ce port manque, relire le dossier et son résultat autoritatif ; ne pas attribuer au clic local une décision prise ailleurs. Une réponse tardive ne remplace jamais un dossier différent désormais affiché.

Pour `request_kyc_document_view`, vérifier ensemble la session, la capacité, le dossier, l’appartenance du document et sa version autorisée à chaque délivrance et renouvellement. Aucun URL/chemin fourni par le client ne choisit librement un objet. Ne pas ouvrir de visualiseur tiers public. Types de fichiers autorisés et limite de dépôt restent ceux du contrat effectif, sans élargissement automatique à PDF, SVG ou HTML.

Pour la liste, autorisation et filtres précèdent pagination et compteurs. **PROPOSITION de tri** : date de soumission croissante puis identifiant stable ; réutiliser la politique existante si différente et justifiée. Préciser explicitement le sens du tri, ne pas charger toute la base côté client.

---

# 18. Copywriting du rôle

Registre : vouvoiement.

Ton : neutre, factuel, dense, sans froideur.

Les actions disent exactement l'effet.

## 18.1 Lexique retenu

Utiliser :

- Dossiers à valider
- Dossier
- Pièce d'identité
- Vérifications
- Valider le dossier
- Refuser le dossier
- Motif du refus
- En cours de vérification
- Profil à compléter

Éviter :

- KYC comme seul libellé visible si une formulation française suffit ;
- Approuver ;
- Rejeter ;
- OK ;
- Valider seul ;
- Refuser seul si le contexte peut être ambigu ;
- Erreur inconnue ;
- Opération réussie ;
- Notification envoyée sans preuve.

## 18.2 Avant / après

1. Avant : `Valider`  
   Après : `Valider le dossier`

2. Avant : `Refuser`  
   Après : `Refuser le dossier`

3. Avant : `Erreur`  
   Après : `Impossible de charger ce dossier.`

4. Avant : `Réessayez plus tard`  
   Après : `Réessayer`

5. Avant : `Aucune donnée`  
   Après : `Aucun dossier n'attend de validation.`

6. Avant : `Document`  
   Après : `Pièce d'identité`

7. Avant : `Utilisateur non autorisé`  
   Après : `Vous n'avez pas accès aux dossiers à valider.`

8. Avant : `Conflit`  
   Après : `Ce dossier a été traité par un autre membre de l'équipe.`

9. Avant : `Profil incomplet`  
   Après : `Votre profil doit être complété avant de consulter les dossiers.`

10. Avant : `Succès`  
    Après : `Dossier validé.`

---

# 19. Responsive et ergonomie par format

## 19.1 Mobile

- AdminShell en tiroir, jamais barre basse.
- Revue séquentielle.
- Liste puis détail.
- Viewer plein écran.
- Feuille basse pour refus.
- Confirmation modale pour validation.
- Cibles 48 dp minimum.
- Une seule action pleine.

## 19.2 Tablette

- rail admin ;
- file et détail si largeur utile réelle ;
- viewer latéral ou modal ;
- souris, clavier et tactile possibles ;
- ne pas supposer touch-only.

## 19.3 Web / ordinateur

Capture de référence obligatoire : 1440 x 900.

Web = vraie interface bureau.

Obligatoire :

- sidebar admin persistante 288 à partir de 1200 ; rail 80 à partir de 600 si le shell le prévoit ;
- padding de page 32 ; sur une capture 1440, zone principale utile 1088 ; master-detail par défaut de cette verticale : 336 + 24 + 728 ;
- header avec recherche de navigation existante, notifications si réellement disponibles, compte ;
- gestion clair/sombre selon shell ;
- hover ;
- focus visible ;
- densité adaptée à la souris ;
- raccourcis seulement s'ils sont documentés ;
- larges zones de respiration ;
- colonnes exploitant la largeur sans étirer le texte ;
- file persistante + détail + viewer possible ;
- pas de composants mobiles géants ;
- pas de CTA pleine largeur si l'espace ne le justifie pas ;
- CTA lié à un bloc : 16 dp sous le bloc, aligné trailing ; un seul CTA dominant par contexte de décision.

---

# 20. Accessibilité

Objectif : WCAG 2.2 AA.

Chaque écran doit respecter :

- contraste AA ;
- ordre de focus logique ;
- focus jamais masqué ;
- navigation clavier complète sur web ;
- labels accessibles sur icônes ;
- état jamais transmis par couleur seule ;
- messages d'erreur associés au composant ;
- texte à 200 % sans perte de fonctionnalité ;
- aucune information sensible uniquement dans une infobulle ;
- viewer accessible au clavier ;
- modal avec focus initial, boucle de focus, retour du focus ;
- réduction des animations ;
- taille de cible minimale compatible avec les standards actuels ;
- pas d'expiration client agressive pendant lecture d'une pièce. La session et les droits peuvent également expirer ; tout renouvellement exige une nouvelle autorisation.

---

# 21. Maquettes à produire

Aucune maquette spécifique `ADM-02` n’existe dans les sources. Les cinq références ci-dessous sont **IMAGE À PRODUIRE**, pas des images livrées ou validées. La présente correction documentaire ne constitue pas une livraison de maquettes.

La verticale doit donc produire de nouvelles références, après validation des propositions UX.

## IMG-ADM-02A_desktop_sombre

Écran : file + détail de dossier sur desktop.  
Format : 1440 x 900.  
Thème : sombre.  
Priorité : obligatoire.

Doit montrer :

- coquille admin complète ;
- Personnes actif ;
- file à gauche ;
- dossier sélectionné au centre ;
- accès à la pièce dans le détail, ouverture en dialogue ;
- vérifications ;
- zone de décision ;
- souris / web density ;
- beaucoup de respiration.

## IMG-ADM-02A_mobile_clair

Écran : file mobile.  
Format : 390 x 844.  
Thème : clair.

## IMG-ADM-02B_mobile_sombre

Écran : revue du dossier mobile.  
Format : 390 x 844.  
Thème : sombre.

## IMG-ADM-02D_desktop_sombre

Écran : refus avec dialogue, desktop.  
Format : 1440 x 900.  
Thème : sombre.

## IMG-ADM-02C_desktop_sombre

Écran : viewer KYC sécurisé, desktop.  
Format : 1440 x 900.  
Thème : sombre.

## Règle de réutilisation

Les composants de shell admin, boutons, champs, dialogue, grouped card, empty state, error state et viewer doivent être partagés.

Ne pas dessiner une nouvelle sidebar si la sidebar admin canonique existe déjà.

---

# 22. Recette fonctionnelle

Le lot opérationnel n’est terminé que si tous les tests suivants sont prouvés.

## 22.1 Accès

- admin autorisé ouvre Personnes et atteint ADM-02 ;
- compteur Accueil ouvre la même route ;
- compte enseignant sans habilitation administrative : accès ADM-02 refusé ;
- compte tuteur sans habilitation administrative : accès ADM-02 refusé ;
- compte élève sans habilitation administrative : accès ADM-02 refusé ;
- compte contrôleur sans habilitation administrative : accès ADM-02 refusé ;
- comptable ne peut pas ouvrir ADM-02 sans permission explicite.

## 22.2 File

- file réelle ou traitement séquentiel existant autorisé ;
- vide réel ;
- pagination ou chargement progressif réel si une file est retenue et le volume le nécessite ;
- filtre ne fabrique pas de résultat ;
- position restaurée après retour.

## 22.3 Dossier

- bon dossier ;
- aucune fuite d'un autre dossier ;
- trois vérifications provenant du vrai contrat ;
- pièce correcte ;
- contrats/accusés uniquement si disponibles ;
- aucune donnée financière inutile.

## 22.4 Pièce

- lecture autorisée ;
- expiration gérée ;
- erreur gérée ;
- aucun secret dans l’interface, l’historique applicatif ou les logs ; vérifier séparément la durée de vie de l’URL présignée ;
- purge des caches contrôlés après déconnexion et refus de renouvellement non autorisé.

## 22.5 Validation

- impossible si `can_validate=false` ;
- confirmation obligatoire ;
- double clic idempotent ;
- conflit concurrent géré ;
- succès uniquement après serveur ;
- file et compteur se mettent à jour.

## 22.6 Refus

- motif obligatoire ;
- motif conservé après erreur ;
- motif affichable dans portail d'attente ;
- aucune note interne inventée ;
- conflit concurrent géré.

## 22.7 Responsive

- 390 clair ;
- 390 sombre ;
- 768 ;
- 1440 clair ou sombre selon maquette ;
- 200 % texte ;
- clavier complet desktop ;
- hover et focus visibles.

## 22.8 Sécurité

- tests RLS ;
- tests storage ;
- tests d'expiration URL ;
- tests de session expirée ;
- tests de rôle ;
- tests d'audit ;
- aucune donnée KYC dans Sentry.

---

# 23. Given / When / Then de recette critique

## AC-01

Étant donné un administrateur autorisé,  
quand il ouvre `Personnes` puis `Dossiers à valider`,  
alors la file de dossiers réellement revue par le serveur apparaît.

## AC-02

Étant donné un dossier sans droit de lecture,  
quand l'identifiant est demandé directement,  
alors aucune donnée personnelle n'est livrée.

## AC-03

Étant donné une pièce KYC disponible,  
quand l'administrateur choisit `Voir la pièce`,  
alors un accès temporaire autorisé est utilisé et aucun chemin de stockage brut n'est affiché.

## AC-04

Étant donné `can_validate=false`,  
quand l'administrateur consulte le dossier,  
alors `Valider le dossier` n'envoie aucune mutation.

## AC-05

Étant donné un dossier validable,  
quand l'administrateur confirme `Valider le dossier`,  
alors le succès n'est affiché qu'après confirmation serveur.

## AC-06

Étant donné deux administrateurs sur le même dossier,  
quand le second agit après la décision du premier,  
alors il reçoit un conflit et aucune seconde décision n'est appliquée.

## AC-07

Étant donné un refus,  
quand aucun motif n'est saisi,  
alors aucune commande serveur n'est envoyée.

## AC-08

Étant donné une erreur réseau pendant une décision,  
quand le résultat serveur est inconnu,  
alors l'interface n'affirme pas que l'action a réussi.

## AC-09

Étant donné 200 % de texte sur desktop,  
quand l'utilisateur navigue au clavier,  
alors le focus reste visible et le contenu n'est pas masqué.

## AC-10

Étant donné un admin dont le genre est absent,  
quand Claude a prouvé qu'aucune règle métier ne dépend de cette donnée,  
alors l'absence du champ ne bloque plus la revue.

## AC-11

Étant donné une règle serveur réelle exigeant le genre,  
quand le profil est incomplet,  
alors ADM-02 renvoie vers l'unique `/compte/profil` au lieu de créer un formulaire local.

---

# 24. Ce que Claude doit absolument vérifier avant d'écrire du code

Checklist obligatoire :

- [ ] route réelle de `ADM-02` ;
- [ ] bouton réel depuis Personnes ;
- [ ] bouton réel depuis compteur Accueil ;
- [ ] trois libellés exacts des vérifications ;
- [ ] source de ces vérifications ;
- [ ] règle `can_validate` ou équivalent ;
- [ ] mécanisme actuel de décision ;
- [ ] atomicité validation + activation ;
- [ ] comportement exact de la règle de genre lorsqu'elle est activée, et emplacement réel de la politique Super Admin ;
- [ ] source et politique de stockage de la pièce ;
- [ ] méthode de lecture sécurisée ;
- [ ] RLS ;
- [ ] audit ;
- [ ] comportement concurrent ;
- [ ] portail d'attente après refus ;
- [ ] absence de notification réelle avant d'en promettre une ;
- [ ] distinction photo publique enseignant / pièce KYC ;
- [ ] composants existants réutilisables ;
- [ ] conformité 2026 documentée dans `UX_REVIEW_03_ADMIN_DOSSIERS.md` ;
- [ ] `DESIGN-GOV-2026-09-26` présent dans la mémoire canonique et le document UX actif ;
- [ ] décision déposée et étape créée dans Suivi Rewayah ;
- [ ] aucun lot terminé rouvert automatiquement pour appliquer la nouvelle gouvernance ;
- [ ] skeleton existant réutilisé pour les nouveaux états de chargement substantiels ;
- [ ] politique Super Admin de genre identifiée côté serveur et tests actif/désactivé préparés.

---

# 25. Hors périmètre

Ne pas construire ici :

- création globale de comptes du personnel ;
- suspension globale de comptes ;
- changement de rôle ;
- registre complet des personnes ;
- paiement ;
- diagnostic pédagogique ;
- attribution de classes ;
- photo publique enseignant ;
- onboarding enseignant complet ;
- messagerie ;
- push ;
- e-mails ;
- historique complet d'audit ;
- conservation des données ;
- suppression de compte ;
- rôle contrôleur ;
- finance ;
- administration complète.

Ces sujets appartiennent à leurs verticales.

---

# 26. Handoff vers `04_ENSEIGNANT.md`

Condition de sortie de ce lot :

un enseignant de test doit pouvoir avoir un dossier réellement revu et recevoir un état serveur exploitable par la porte d'accès.

`03` ne définit pas encore l'expérience complète après activation.

`04_ENSEIGNANT.md` définira :

- Premiers pas ;
- Journée ;
- marketplace / réservation de Classes ;
- Classes attribuées ;
- espace Classe ;
- préparation ;
- séance ;
- cahier ;
- travail ;
- signalements ;
- ressources ;
- photo publique ;
- absences et remplacement ;
- profil et préférences.

Claude ne doit pas anticiper ces écrans dans `03`.

---

# 26 bis. Parcours complémentaires obligatoires

Ces compléments sont des **PROPOSITIONS de spécification**, à raccorder aux règles existantes ; ils ne créent aucune obligation KYC nouvelle.

## P-ADM-08 - Revoir le dossier d’un tuteur ou d’une famille

1. Depuis Personnes ou le compteur Accueil, ouvrir le dossier du titulaire concerné.
2. Afficher le rôle réel, les éléments soumis et les seuls prérequis applicables à cette personne. La présence d’enfants n’autorise pas l’accès à leurs pièces ou données sans nécessité et permission distinctes.
3. Si la politique dispense de pièce, afficher `Aucune pièce requise pour ce dossier.` ; ne pas simuler une pièce reçue ou bloquer pour son absence.
4. Si une pièce est requise mais absente, afficher `La pièce requise n’a pas été transmise.` ; validation indisponible, refus seulement si autorisé. Un dossier incomplet peut être exclu de la file par la politique existante : ne pas le fabriquer pour ce scénario.
5. Effectuer les contrôles applicables et ouvrir ADM-02E pour valider, ou ADM-02D pour refuser.
6. Après réponse autoritative, actualiser file et compteur. Côté titulaire, le portail relit l’état ; aucun accès d’enfant, inscription, paiement ou attribution de classe n’est déduit de la décision seule.
7. Au retour, retrouver la file avec ses filtres. En erreur, conserver le dossier et permettre une reprise sans double décision.

## P-ADM-09 - Refus, correction et nouvelle soumission

1. Le titulaire ouvre `/attente`, voit `Dossier refusé` et le motif public enregistré.
2. Montrer `Corriger` uniquement si le contrat l’autorise ; utiliser les destinations existantes `/attente/accuse`, `/attente/contrat`, `/attente/piece` selon les éléments à corriger. Aucune nouvelle route d’inscription concurrente.
3. Réutiliser les libellés de ces écrans et leur envoi existant. Le refus ne vaut pas promesse d’acceptation future.
4. Une correction locale ne remet pas le dossier en file. La soumission confirmée crée une nouvelle révision serveur ou l’équivalent existant et un état de revue effectif.
5. L’administration charge la nouvelle révision. Les contrôles de l’ancienne pièce ne sont pas repris automatiquement comme preuves de la nouvelle.
6. Si la correction n’est pas autorisée, afficher `Ce dossier ne peut pas être modifié pour le moment.` ; sortie `Se déconnecter`. Ne pas créer un bouton support si aucun service n’existe.
7. La suspension demeure indépendante et n’est levée ni par la correction ni par la validation documentaire.

## P-ADM-10 - Réponse perdue pendant une décision

1. Après confirmation, désactiver validation et refus pour cette commande.
2. Si la réponse est perdue, afficher `Le résultat de la décision n’est pas encore confirmé.` et `Vérifier le résultat`.
3. Relire le résultat autoritatif. Ne pas présenter un timeout comme un refus métier ou un échec certain.
4. Si le serveur confirme la commande, afficher son résultat une seule fois. Si un autre administrateur a décidé, afficher le conflit.
5. Toute répétition autorisée conserve le même identifiant de commande et la même charge utile. Un changement de décision nécessite un nouvel état serveur et une nouvelle confirmation.
6. Tant que le résultat demeure inconnu, aucune nouvelle décision opposée ; navigation et déconnexion restent possibles, sans affirmer que quitter annule la commande.

## P-ADM-11 - Retour de la personne après validation

1. Le portail d’attente relit l’état au retour de l’application, après une actualisation demandée et selon le mécanisme déjà disponible. Ne pas supposer une notification push.
2. Si actif, la garde utilise la racine existante : enseignant `/enseignant/journee`, tuteur `/tuteur`, élève adulte `/eleve` si ce type est réellement concerné.
3. Si une condition demeure, rester sur la porte appropriée avec le statut réel. La validation ne garantit ni Classe attribuée ni accès visio.
4. Ne pas rediriger l’enseignant vers « Premiers pas » par anticipation de `04`. Ce choix relève de sa verticale.

---

# 26 ter. Compléments de fiches, états et composants

## Composition partagée obligatoire

`AdminShell` porte la navigation, `PageShell` le gabarit, `EntetePage` le titre et `DisqueRetour` le retour. L’exception administrative à huit domaines est conservée (dossier C §8), sans appliquer la barre basse des autres rôles. `GroupeReglages` et `LigneRubrique` portent les lignes regroupées ; `ActionPrincipale` porte les actions ; `StatusPill` les statuts ; `EtatSysteme`, `BlocAsynchrone`, `Skeleton` et `OfflineBanner` les états réellement compatibles avec la surface.

Marges de page : 16 mobile, 24 tablette, 32 desktop. Entre sections : 24 ; entre titre de bloc et contenu : 8 ; entre champs : 12 ; marges internes selon le composant gelé. Rayons, couleurs et polices viennent des jetons. Aucun nouveau jeton global pour ce lot. Titres DM Sans, autres textes famille Jakarta déjà déclarée. Les noms en écriture arabe respectent leur direction, sans retourner les codes, dates ou commandes françaises.

Le pied de décision réserve sa hauteur réelle dans le contenu défilant et respecte clavier logiciel et zone sûre. À 200 %, les actions peuvent s’empiler, sans texte tronqué. Cibles au moins 48 dp selon Rewayah ; un dessin compact ne réduit pas la zone d’interaction. La touche Entrée dans le champ multiligne n’envoie pas le refus.

Dates : instants serveur en UTC, affichage dans le fuseau du profil admin, sinon celui de l’appareil explicitement indiqué ; `dd/MM/yyyy à HH:mm (zone IANA)`. Date seule inconnue : `Date de dépôt indisponible`. Le relatif ne remplace pas la date accessible. Identité absente : `Dossier sans nom disponible`, puis blocage si le contrat le requiert ; aucun nom fictif en production.

## ADM-02A - compléments

Entrées : Personnes et compteur Accueil, route canonique unique. Retour de niveau principal : Accueil admin. Le retour de détail restaure sélection, défilement et filtres autorisés en mémoire de session, jamais la pièce ou le motif dans une URL.

| État | Texte exact | Action et comportement |
|---|---|---|
| Actualisation | `Actualisation des dossiers…` | Conserver la liste déjà autorisée, marquer son actualisation |
| Chargement prolongé | `Le chargement prend plus de temps que prévu.` | Conserver retour et navigation |
| Aucun résultat filtré | `Aucun dossier ne correspond à ce filtre.` | `Effacer le filtre`, distinct du vide global |
| Page suivante en erreur | `Impossible de charger les dossiers suivants.` | `Réessayer`, conserver les lignes chargées |
| Capacité absente | `La consultation des dossiers est indisponible pour le moment.` | `Retour à l’accueil`, aucune fausse liste vide |
| Sélection retirée | `Ce dossier n’est plus disponible dans la file.` | `Actualiser les dossiers` |
| Aucun détail sélectionné | `Sélectionnez un dossier à examiner.` | Sélection depuis la liste |

Libellés accessibles : `Ouvrir le dossier de {nom}`, `Actualiser les dossiers`, `Charger les dossiers suivants`. Une ligne sélectionnée expose cet état autrement que par sa couleur. En sélection automatique desktop, aucune pièce ne s’ouvre seule. Après décision, annoncer `Dossier suivant : {nom}` et réinitialiser les contrôles locaux ; ne jamais reporter les coches du dossier précédent. Référence : IMG-ADM-02A_desktop_sombre et IMG-ADM-02A_mobile_clair.

## ADM-02B - compléments

Entrée : ligne sélectionnée dans ADM-02A. Sorties : retour à la file ; `Voir la pièce` vers ADM-02C ; `Refuser le dossier` vers ADM-02D ; `Valider le dossier` vers ADM-02E. Le détail n’ajoute aucune route parallèle.

| État | Texte exact | Action et comportement |
|---|---|---|
| Chargement | `Chargement du dossier…` | Décisions indisponibles |
| Hors ligne | `Vous êtes hors ligne. Aucune décision ne peut être envoyée.` | `Réessayer`, aucune file de mutations différées |
| Permission perdue | `Vous n’avez plus accès à ce dossier.` | `Retour aux dossiers`, purger le contenu |
| Vérifications incomplètes | `Terminez les vérifications requises.` | Conduire au premier contrôle concerné |
| Accord manquant | `Un accord requis manque à ce dossier.` | Aucune acceptation au nom du titulaire |
| Service absent | `La décision est indisponible pour le moment.` | Lecture autorisée conservée, mutations indisponibles |
| Dossier modifié | `Ce dossier a changé depuis son ouverture.` | `Actualiser le dossier`, recharger contrôles et pièce |
| Refus non autorisé | `Ce dossier ne peut pas être refusé dans son état actuel.` | Refus indisponible, validation selon sa propre capacité |

Ne pas confondre absence de contrôle et contrôle négatif. Le serveur fournit les raisons structurées ; l’i18n les traduit, jamais une erreur SQL brute. L’ordre sémantique suit titre, statut, identité, pièce, vérifications, accords, décision. Référence : IMG-ADM-02B_mobile_sombre.

## ADM-02C - compléments

Surface interne sans route publique, destination Personnes, entrée unique `Voir la pièce`. Une commande visible `Fermer` suffit : retour système et Échap réalisent cette même fermeture, puis rendent le focus au déclencheur. En plein écran mobile, utiliser un retour visible avec libellé accessible `Fermer la pièce`. La déconnexion reste accessible après fermeture, sans impasse.

| État | Texte exact | Action et comportement |
|---|---|---|
| Aucune pièce | `Aucune pièce n’est disponible.` | `Fermer` |
| Format non pris en charge | `Ce format de pièce ne peut pas être affiché.` | `Fermer`, pas de conversion publique ni téléchargement implicite |
| Hors ligne | `Vous êtes hors ligne. La pièce ne peut pas être chargée.` | `Réessayer` ou `Fermer` |
| Accès retiré | `Vous n’avez plus accès à cette pièce.` | Effacer l’image et `Fermer` |
| Lecture indisponible | `La consultation de la pièce est indisponible pour le moment.` | `Fermer` |
| Contenu | `Pièce d’identité` | Zoom et lecture, jamais validation depuis ce viewer |

Commandes de zoom : `Agrandir`, `Réduire`, `Ajuster à l’écran`. Si rotation réellement disponible : `Tourner la pièce`. Si plusieurs pages sont effectivement prises en charge : `Page précédente`, `Page suivante`, `Page {n} sur {total}`. Pas d’OCR ajouté ni transcription automatique de la pièce. Le contrôle est accessible au clavier ; la seule description de l’image ne prouve pas l’accessibilité du contenu scanné.

Mobile 390 : plein écran, en-tête puis document et commandes ; tablette 768 : plein écran dans l’espace disponible ; desktop 1440 : dialogue large borné par le gabarit de lecture 800, marges 32, hauteur contenue dans le viewport, commandes toujours accessibles. Le dialogue est modal ; un panneau non modal éventuel ne piège pas le focus. Référence : IMG-ADM-02C_desktop_sombre.

## ADM-02D - compléments

Surface interne de ADM-02B, destination Personnes. À 390 : feuille haute défilante avec titre, nom/type, explication, champ multiligne, aide, erreur associée, puis Annuler et Refuser. Avec clavier ou texte agrandi, utiliser toute la hauteur utile. À 768 et 1440 : dialogue de largeur maximale 560, marges 24, mêmes blocs dans le même ordre. Bouton destructif du système gelé, sans nouveau fond rouge.

Le nom et la révision du dossier restent ceux de la demande initiale ; le motif n’est jamais appliqué à un autre dossier. Longueur maximale : valeur du contrat effectif, validation identique côté serveur. Texte trop long : `Le motif dépasse la longueur autorisée.` ; caractères seuls d’espacement : erreur vide existante. Aucun motif stocké dans URL, logs ou stockage local persistant.

| État | Texte exact | Action et comportement |
|---|---|---|
| Hors ligne avant envoi | `Vous êtes hors ligne. Le refus n’a pas été envoyé.` | Conserver le motif en mémoire, `Réessayer` après reconnexion |
| Résultat inconnu | `Le résultat du refus n’est pas encore confirmé.` | `Vérifier le résultat`, jamais nouvel envoi aveugle |
| Refus interdit | `Vous ne pouvez plus refuser ce dossier.` | `Fermer`, actualiser les droits |
| Service absent | `Le refus est indisponible pour le moment.` | `Annuler`, aucun faux succès |
| Succès | `Dossier refusé.` | Fermer, retirer de la file, focus au point de reprise |

Avant envoi, fermer par Échap, retour ou Annuler ne décide rien. Si un motif saisi va être perdu : `Abandonner le motif saisi ?`, `Continuer la saisie`, `Abandonner`. Pendant envoi, fermer n’annule pas la commande serveur ; le suivi du résultat reste attaché à son identifiant. Après erreur certaine, conserver le motif tant que la session et le dossier restent autorisés. Après déconnexion ou retrait des droits, le purger. Focus initial au champ, erreur annoncée, retour au bouton d’ouverture à l’annulation. Référence : IMG-ADM-02D_desktop_sombre.

## ADM-02E - compléments

Surface interne de ADM-02B, destination Personnes, sans nouvelle route. Entrée unique `Valider le dossier`. À 390 : dialogue dans les marges 16, contenu défilant si nécessaire ; à 768/1440 : largeur maximale 560, marges internes 24. Ordre : titre, nom/type, conséquence autoritative, blocages éventuels, Annuler, Valider. Une seule action pleine dans le dialogue actif, page sous-jacente non interactive.

| État | Texte exact | Action et comportement |
|---|---|---|
| Hors ligne avant envoi | `Vous êtes hors ligne. La validation n’a pas été envoyée.` | `Annuler`, aucune mutation différée |
| Résultat inconnu | `Le résultat de la validation n’est pas encore confirmé.` | `Vérifier le résultat` |
| Prérequis modifiés | `Ce dossier n’est plus prêt à être validé.` | `Actualiser le dossier`, nouvelle confirmation nécessaire |
| Permission perdue | `Vous ne pouvez plus valider ce dossier.` | `Fermer`, purger les données non autorisées |
| Service absent | `La validation est indisponible pour le moment.` | `Annuler` |
| Succès | `Dossier validé.` | Fermer et actualiser la file, sans promettre l’activation |

Focus initial sur le titre ou Annuler, jamais activation immédiate par Entrée lors de l’ouverture. Retour et Échap ferment avant envoi sans mutation. Pendant envoi, appliquer P-ADM-10. Une réponse d’échec certaine autorise une reprise ; le timeout seul ne la prouve pas. Référence : IMG-ADM-02E_mobile_clair, **IMAGE À PRODUIRE**, ajoutée pour couvrir cette confirmation.

---

# 26 quater. Preuves UX, sécurité et livraison

## Références effectivement consultées le 26/09/2026

| Référence officielle | Conséquence dans cette révision |
|---|---|
| [Flutter, pratiques adaptatives](https://docs.flutter.dev/ui/adaptive-responsive/best-practices) | Composition selon largeur utile et moyens d’entrée ; retour qui conserve l’état de liste |
| [WCAG 2.2, Reflow 1.4.10](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html) | Ajouter un test à 320 pixels CSS de largeur équivalente, notamment 400 % de zoom à partir de 1280 ; 200 % de texte seul ne suffit pas |
| [WCAG 2.2, Focus non masqué 2.4.11](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html) | Le pied fixe ne doit pas masquer le composant focalisé ; Rewayah vise une visibilité complète |

Ce contrôle documentaire ne certifie ni conformité WCAG globale ni conformité réglementaire. La référence à EN 301 549 demande une édition précise vérifiée au moment de son application. Les autres référentiels du §4 restent à confronter au rendu réel. GOV.UK est explicitement exclu comme référence de design Rewayah par décision du directeur du 26/09/2026.

### Publication orchestrateur et dette d'harmonisation

L'orchestrateur publie `DESIGN-GOV-2026-09-26` dans la mémoire canonique, le document UX actif et Suivi Rewayah avant de distribuer de nouveaux lots visuels. Cette publication ne déclenche pas une refonte rétroactive immédiate. Une étape séparée `Harmonisation UI globale après visuels de tous les rôles` reste `à faire` jusqu'à ce que les visuels de tous les rôles soient implémentés, sauf ordre contraire du directeur.

Le lot **Tuteur - compléments** est l'exemple de référence : ses écarts visuels sont consignés dans cette dette globale ; ils ne justifient ni rollback, ni reset de branche, ni reprise générale de la vague à ce stade.

## Recette additionnelle obligatoire

| Identifiant | Étant donné / Quand / Alors |
|---|---|
| AC-12 | Étant donné une famille dispensée de pièce par la politique effective, quand l’admin ouvre son dossier depuis la file, alors aucune pièce n’est rendue obligatoire localement. |
| AC-13 | Étant donné un refus corrigeable, quand le titulaire touche Corriger, soumet et reçoit confirmation, alors une nouvelle révision est revue sans réemploi automatique de preuves obsolètes. |
| AC-14 | Étant donné une décision enregistrée avec réponse perdue, quand l’admin vérifie ou répète la même commande, alors une seule décision et une seule trace de succès existent. |
| AC-15 | Étant donné un document d’un autre dossier, quand son identifiant est substitué dans la demande de lecture, alors aucun accès ni contenu n’est délivré. |
| AC-16 | Étant donné des droits retirés après ouverture, quand le client relit, renouvelle ou décide, alors le serveur refuse et les données contrôlées sont purgées. |
| AC-17 | Étant donné une pièce remplacée pendant revue, quand l’admin valide l’ancienne révision, alors le serveur refuse et demande une nouvelle revue. |
| AC-18 | Étant donné une suspension, quand le dossier est validé, alors l’état suspendu reste effectif jusqu’à sa procédure dédiée. |
| AC-19 | Étant donné un appel direct à la décision sans contrôles requis, quand l’API est appelée malgré le bouton désactivé, alors le serveur refuse. |
| AC-20 | Étant donné un viewport 1440, quand file et détail sont affichés, alors les colonnes tiennent dans 1088 dp et le viewer reste modal. |
| AC-21 | Étant donné une largeur équivalente 320 CSS px et du texte agrandi, quand chaque surface est parcourue au clavier, alors commandes et focus restent accessibles. |
| AC-22 | Étant donné un motif saisi, quand l’admin annule puis choisit Continuer la saisie, alors le motif est conservé sans décision. |
| AC-23 | Étant donné une validation effective, quand le titulaire actualise son portail, alors la garde utilise son état d’accès réel et sa racine existante. |

Les accès sont testés par capacités et périmètres : sans habilitation, admin inclus, aucune revue ; aucun octroi de capacité à un autre rôle par cette spec. Tester aussi changement de compte sur le même appareil et arrivée tardive d’une réponse pour le dossier précédent.

## Démonstration et preuves visuelles

Réutiliser le mode démonstration par rôle demandé dans le dossier A §1 ter-6, seulement hors production, sans appel serveur ni donnée réelle. Mention visible `Démonstration`. Les documents de test sont synthétiques et portent `Document fictif`, sans vraie identité. Aucune capture de recette ne contient de pièce réelle, de motif réel ou de lien signé. Ne pas présenter ces fixtures comme une validation backend.

Six références d’images au total : les cinq du §21 et IMG-ADM-02E_mobile_clair. Pour chacune, la fiche de surface et ses compléments fixent blocs, textes, composants et états. Le scénario nominal utilise des données synthétiques explicitement identifiées. Les libellés des trois contrôles restent à extraire du code : aucune maquette nominale finale ne doit les inventer. Statut des six images : **IMAGE À PRODUIRE**. Les maquettes tuteur jointes ne deviennent pas des références de composition admin.

## État de livraison à distinguer

- Spécification corrigée : présente dans ce fichier.
- Faits historiques du code : rapportés par le dossier, non réaudités ici.
- Trois libellés de contrôle, raison du genre, politique KYC effective, services et atomicité : à vérifier dans le dépôt et l’environnement autorisé.
- UI construite, maquettes rendues, tests locaux, staging et déploiement : non réalisés dans cette révision.
- Frontend en démonstration : peut être terminé indépendamment, mais ne débloque pas réellement un enseignant.
- Verticale opérationnelle : reste non terminée tant que les critères du §28 manquent.

## Journal des corrections V1.2

Hiérarchie alignée sur la source canonique ; faits rattachés à leurs sections ; familles et resoumission couvertes ; largeur desktop/tablette corrigée ; validation séparée de l’accès ; refus autorisé séparément ; droits fondés sur capacités ; contrainte de genre transformée en politique Super Admin activable/désactivable ; contrats Spacing & Layout, CTA & Actions, Component Anatomy, Responsive Desktop et Interaction & Motion figés ; skeleton existant remis au premier plan ; GOV.UK retiré des références ; publication obligatoire dans mémoire canonique et Suivi Rewayah ; interdiction de rouvrir automatiquement les lots terminés ; harmonisation rétroactive différée après implémentation des visuels de tous les rôles ; exemple Tuteur - compléments consigné comme dette sans marche arrière ; contrôles liés aux versions ; idempotence et résultat inconnu précisés ; autorisation de pièce liée au dossier ; limites des URL présignées explicitées ; états et messages complétés ; références visuelles alignées ; définition de fini sans faux succès.

---

# 27. Auto-contrôle

Statut : auto-contrôle de la rédaction seulement. Cinq surfaces principales, deux états intégrés, onze parcours, vingt-trois scénarios critiques, six images à produire. Aucun test applicatif déclaré exécuté. Les textes des trois contrôles ne sont pas disponibles dans les sources : cette limite demeure explicite.

## 27.1 Surfaces spécifiées

1. ADM-02A Dossiers à valider
2. ADM-02B Revue du dossier
3. ADM-02C Viewer sécurisé de pièce
4. ADM-02D Refuser le dossier
5. ADM-02E Confirmer la validation
6. état intégré de décision réussie
7. dépendance intégrée de profil admin

## 27.2 Parcours couverts

1. entrée par Personnes
2. entrée par Accueil
3. revue enseignant
4. refus
5. conflit concurrent
6. pièce inaccessible
7. politique de genre KYC
8. revue famille
9. refus et nouvelle soumission
10. résultat de décision incertain
11. retour du titulaire après validation

## 27.3 Maquettes demandées

1. IMG-ADM-02A_desktop_sombre
2. IMG-ADM-02A_mobile_clair
3. IMG-ADM-02B_mobile_sombre
4. IMG-ADM-02D_desktop_sombre
5. IMG-ADM-02C_desktop_sombre
6. IMG-ADM-02E_mobile_clair

## 27.4 Contrôles documentaires uniquement, pas des tests de l’application

- [x] aucune règle KYC non prouvée n'est inventée ;
- [x] les trois vérifications ne reçoivent pas de faux libellé ;
- [x] une fonction possède un endroit canonique ;
- [x] ADM-08 n'est pas dupliqué ;
- [x] `/compte/profil` n'est pas dupliqué ;
- [x] aucune notification inexistante n'est promise ;
- [x] aucun succès n'est local ;
- [x] KYC et photo publique restent séparés ;
- [x] le web est traité comme une vraie interface bureau ;
- [x] mobile, tablette et desktop sont explicités ;
- [x] clavier, souris, hover et focus sont couverts ;
- [x] WCAG 2.2 AA est imposé ;
- [x] Claude doit revalider les propositions contre les standards 2026 ;
- [x] les dérogations UX doivent être documentées ;
- [x] la sécurité prime sur la maquette ;
- [x] absence de lien sensible dans l’interface exigée, limites d’une URL présignée documentées ;
- [x] la concurrence de décision est couverte ;
- [x] la décision serveur est attendue avant succès ;
- [x] la règle de genre est une politique Super Admin configurable ; le comportement actif reste à mapper sur le serveur réel ;
- [x] le handoff vers Enseignant est explicite ;
- [x] le périmètre est fermé ;
- [x] GOV.UK n'est pas une référence de design Rewayah ;
- [x] les cinq contrats de gouvernance design sont figés ;
- [x] les skeletons existants sont réaffirmés sans redessin ;
- [x] l'orchestrateur doit publier la décision dans la mémoire canonique et Suivi Rewayah ;
- [x] aucune reprise automatique des étapes terminées n'est autorisée ;
- [x] l'harmonisation rétroactive est différée après les visuels de tous les rôles sauf ordre explicite du directeur ;
- [x] le lot Tuteur - compléments est cité comme exemple de dette à reporter sans marche arrière.

---

# 28. Condition de définition de fini

Le lot `03_ADMIN_VALIDATION_DOSSIERS` est fini uniquement si :

1. un administrateur autorisé atteint ADM-02 depuis l’UI, en file ou traitement séquentiel existant ;
2. un dossier réel accessible est ouvert, par sélection ou selon le traitement séquentiel retenu ;
3. la pièce réelle peut être lue selon une autorisation serveur ;
4. les trois vérifications réelles sont affichées ;
5. le dossier ne peut pas être validé contrairement au serveur ;
6. le refus exige un motif ;
7. les décisions et leur audit sont atomiques, avec effets d’accès prouvés ;
8. la concurrence est gérée ;
9. l'audit existe ;
10. aucun compte dépourvu de capacité et de périmètre autorisés n’accède aux pièces de tiers ;
11. la politique de genre KYC est lue côté serveur, configurable uniquement par Super Admin, testée activée et désactivée, et n'accorde jamais plus que la capability/périmètre KYC existants ;
12. les layouts 390, 768 et 1440 sont validés ;
13. le 1440 est une vraie interface desktop ;
14. l'audit UX 2026 est livré ;
15. `DESIGN-GOV-2026-09-26` est publié dans la mémoire canonique, le document UX actif et Suivi Rewayah, sans réouvrir automatiquement les lots terminés ;
16. tous les tests critiques sont verts avec preuves ; toute dépendance bloquante maintient le statut opérationnel « NON TERMINÉ ».

La conception et les travaux indépendants de `04_ENSEIGNANT.md` peuvent continuer avant cette recette. Le parcours réel de l’enseignant ne sera déclaré débloqué qu’après satisfaction des critères ci-dessus. Aucun bilan documentaire ne remplace les preuves d’exécution.

La publication de cette V1.2 n'est pas une consigne de reprise générale des écrans déjà construits. Le programme continue vers les visuels des rôles suivants. La passe d'harmonisation design transversale intervient après implémentation des visuels de tous les rôles, sauf demande ciblée du directeur.
